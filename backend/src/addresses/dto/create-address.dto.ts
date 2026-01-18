import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsBoolean, IsNumber } from 'class-validator';

export class CreateAddressDto {
  @ApiProperty({ description: 'Address name (Home, Work, etc.)' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Street address' })
  @IsString()
  street: string;

  @ApiPropertyOptional({ description: 'Apartment number' })
  @IsString()
  @IsOptional()
  apartment?: string;

  @ApiPropertyOptional({ description: 'Entrance number' })
  @IsString()
  @IsOptional()
  entrance?: string;

  @ApiPropertyOptional({ description: 'Floor' })
  @IsString()
  @IsOptional()
  floor?: string;

  @ApiPropertyOptional({ description: 'Intercom code' })
  @IsString()
  @IsOptional()
  intercom?: string;

  @ApiPropertyOptional({ description: 'Latitude' })
  @IsNumber()
  @IsOptional()
  latitude?: number;

  @ApiPropertyOptional({ description: 'Longitude' })
  @IsNumber()
  @IsOptional()
  longitude?: number;

  @ApiPropertyOptional({ description: 'Set as default address' })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class UpdateAddressDto {
  @ApiPropertyOptional({ description: 'Address name (Home, Work, etc.)' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ description: 'Street address' })
  @IsString()
  @IsOptional()
  street?: string;

  @ApiPropertyOptional({ description: 'Apartment number' })
  @IsString()
  @IsOptional()
  apartment?: string;

  @ApiPropertyOptional({ description: 'Entrance number' })
  @IsString()
  @IsOptional()
  entrance?: string;

  @ApiPropertyOptional({ description: 'Floor' })
  @IsString()
  @IsOptional()
  floor?: string;

  @ApiPropertyOptional({ description: 'Intercom code' })
  @IsString()
  @IsOptional()
  intercom?: string;

  @ApiPropertyOptional({ description: 'Latitude' })
  @IsNumber()
  @IsOptional()
  latitude?: number;

  @ApiPropertyOptional({ description: 'Longitude' })
  @IsNumber()
  @IsOptional()
  longitude?: number;
}
