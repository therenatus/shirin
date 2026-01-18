import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';

@Injectable()
export class StorageService implements OnModuleInit {
  private readonly logger = new Logger(StorageService.name);
  private minioClient: Minio.Client;
  private bucketName = 'shirin';

  constructor(private configService: ConfigService) {
    this.minioClient = new Minio.Client({
      endPoint: this.configService.get<string>('minio.endPoint') || 'localhost',
      port: this.configService.get<number>('minio.port') || 9000,
      useSSL: this.configService.get<boolean>('minio.useSSL') || false,
      accessKey: this.configService.get<string>('minio.accessKey') || 'minioadmin',
      secretKey: this.configService.get<string>('minio.secretKey') || 'minioadmin',
    });
  }

  async onModuleInit() {
    await this.ensureBucketExists();
  }

  private async ensureBucketExists() {
    try {
      const exists = await this.minioClient.bucketExists(this.bucketName);
      if (!exists) {
        await this.minioClient.makeBucket(this.bucketName);
        this.logger.log(`Bucket "${this.bucketName}" created`);

        // Set public read policy
        const policy = {
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Principal: { AWS: ['*'] },
              Action: ['s3:GetObject'],
              Resource: [`arn:aws:s3:::${this.bucketName}/*`],
            },
          ],
        };
        await this.minioClient.setBucketPolicy(
          this.bucketName,
          JSON.stringify(policy),
        );
        this.logger.log(`Public read policy set for bucket "${this.bucketName}"`);
      } else {
        this.logger.log(`Bucket "${this.bucketName}" already exists`);
      }
    } catch (error) {
      this.logger.error('Failed to initialize bucket:', error.message);
    }
  }

  async uploadFile(
    file: Express.Multer.File,
    folder: string = 'uploads',
  ): Promise<string> {
    const fileName = `${folder}/${Date.now()}-${file.originalname.replace(/\s+/g, '-')}`;

    await this.minioClient.putObject(
      this.bucketName,
      fileName,
      file.buffer,
      file.size,
      { 'Content-Type': file.mimetype },
    );

    const endpoint = this.configService.get<string>('minio.endPoint');
    const port = this.configService.get<number>('minio.port');
    const useSSL = this.configService.get<boolean>('minio.useSSL');
    const protocol = useSSL ? 'https' : 'http';

    return `${protocol}://${endpoint}:${port}/${this.bucketName}/${fileName}`;
  }

  async deleteFile(fileUrl: string): Promise<boolean> {
    try {
      const url = new URL(fileUrl);
      const objectName = url.pathname.replace(`/${this.bucketName}/`, '');
      await this.minioClient.removeObject(this.bucketName, objectName);
      return true;
    } catch (error) {
      this.logger.error('Failed to delete file:', error.message);
      return false;
    }
  }

  async getSignedUrl(objectName: string, expiry: number = 3600): Promise<string> {
    return this.minioClient.presignedGetObject(this.bucketName, objectName, expiry);
  }
}
