import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';

@Injectable()
export class StorageService implements OnModuleInit {
  private readonly logger = new Logger(StorageService.name);
  private readonly client: Minio.Client;
  private readonly bucketName: string;
  private readonly publicUrl: string;

  constructor(configService: ConfigService) {
    // `minio` is used as a generic S3 client; the server is SeaweedFS (or any S3)
    this.client = new Minio.Client({
      endPoint: configService.getOrThrow<string>('storage.endPoint'),
      port: configService.getOrThrow<number>('storage.port'),
      useSSL: configService.get<boolean>('storage.useSSL') ?? false,
      accessKey: configService.getOrThrow<string>('storage.accessKey'),
      secretKey: configService.getOrThrow<string>('storage.secretKey'),
      pathStyle: true,
    });
    this.bucketName = configService.getOrThrow<string>('storage.bucket');
    this.publicUrl = configService.getOrThrow<string>('storage.publicUrl');
  }

  async onModuleInit() {
    await this.ensureBucketExists();
  }

  /**
   * Public read access for the bucket is configured on the storage side
   * (anonymous identity in infra/seaweedfs/entrypoint.sh), not via bucket policy.
   */
  private async ensureBucketExists() {
    try {
      const exists = await this.client.bucketExists(this.bucketName);
      if (!exists) {
        await this.client.makeBucket(this.bucketName);
        this.logger.log(`Bucket "${this.bucketName}" created`);
      } else {
        this.logger.log(`Bucket "${this.bucketName}" already exists`);
      }
    } catch (error) {
      this.logger.error(
        `Failed to initialize bucket: ${(error as Error).message}`,
      );
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'uploads',
  ): Promise<string> {
    const fileName = `${folder}/${Date.now()}-${file.originalname.replace(/\s+/g, '-')}`;

    await this.client.putObject(
      this.bucketName,
      fileName,
      file.buffer,
      file.size,
      { 'Content-Type': file.mimetype },
    );

    return `${this.publicUrl}/${this.bucketName}/${fileName}`;
  }

  async deleteFile(fileUrl: string): Promise<boolean> {
    try {
      const url = new URL(fileUrl);
      const objectName = url.pathname.replace(`/${this.bucketName}/`, '');
      await this.client.removeObject(this.bucketName, objectName);
      return true;
    } catch (error) {
      this.logger.error(`Failed to delete file: ${(error as Error).message}`);
      return false;
    }
  }

  async getSignedUrl(
    objectName: string,
    expiry: number = 3600,
  ): Promise<string> {
    return this.client.presignedGetObject(this.bucketName, objectName, expiry);
  }
}
