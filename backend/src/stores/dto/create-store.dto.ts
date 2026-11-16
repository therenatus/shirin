import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import {
  IsBoolean,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateStoreDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  nameRu?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  nameKy?: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  addressRu?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  addressKy?: string;

  @ApiProperty({ example: 42.8746 })
  @IsLatitude()
  latitude: number;

  @ApiProperty({ example: 74.5698 })
  @IsLongitude()
  longitude: number;

  @ApiProperty({ example: '+996 312 901 234' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ example: '08:00 - 22:00' })
  @IsString()
  @IsNotEmpty()
  workHours: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  image?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateStoreDto extends PartialType(CreateStoreDto) {}
