import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { CoffeeSize } from '@prisma/client';

export class ClaimCoffeeDto {
  @ApiProperty({ description: 'Customer QR code from the mobile app' })
  @IsString()
  @IsNotEmpty()
  qrCode: string;

  @ApiProperty({ enum: CoffeeSize })
  @IsEnum(CoffeeSize)
  size: CoffeeSize;
}
