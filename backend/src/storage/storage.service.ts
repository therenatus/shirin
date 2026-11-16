import {
  BadRequestException,
  Injectable,
  OnModuleInit,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';
import { randomUUID } from 'crypto';

/** Image types customers may upload, detected from the file's first bytes. */
const IMAGE_SIGNATURES: {
  ext: string;
  mime: string;
  test: (b: Buffer) => boolean;
}[] = [
  {
    ext: 'jpg',
    mime: 'image/jpeg',
    test: (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff,
  },
  {
    ext: 'png',
    mime: 'image/png',
    test: (b) =>
      b
        .subarray(0, 8)
        .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  },
  {
    ext: 'webp',
    mime: 'image/webp',
    test: (b) =>
      b.subarray(0, 4).toString('ascii') === 'RIFF' &&
      b.subarray(8, 12).toString('ascii') === 'WEBP',
  },
];

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

  /**
   * Customer upload of a reference photo for a custom cake. The key is built
   * on the server (no client-controlled path or name) and the type is taken
   * from the file content, not from the client's Content-Type.
   */
  async uploadReferencePhoto(userId: string, file: Express.Multer.File) {
    const type = IMAGE_SIGNATURES.find((t) => t.test(file.buffer));
    if (!type) {
      throw new BadRequestException('Only JPEG, PNG or WebP photos');
    }
    const key = `${this.referencePrefix(userId)}${randomUUID()}.${type.ext}`;
    await this.client.putObject(this.bucketName, key, file.buffer, file.size, {
      'Content-Type': type.mime,
    });
    return `${this.publicUrl}/${this.bucketName}/${key}`;
  }

  /** True if the URL is a reference photo uploaded by this user. */
  isReferencePhotoOf(url: string, userId: string): boolean {
    const prefix = `${this.publicUrl}/${this.bucketName}/${this.referencePrefix(userId)}`;
    return (
      url.startsWith(prefix) &&
      /^[\w-]+\.(jpg|png|webp)$/.test(url.slice(prefix.length))
    );
  }

  private referencePrefix(userId: string) {
    return `references/${userId}/`;
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
