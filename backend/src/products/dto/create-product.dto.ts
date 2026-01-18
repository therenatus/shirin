import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsArray,
  IsUUID,
  Min,
} from 'class-validator';

export class CreateProductDto {
  @ApiProperty()
  @IsString()
  name: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameKy?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameRu?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  descriptionKy?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  descriptionRu?: string;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  price: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  discountPrice?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  images?: string[];

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  ingredients?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  weight?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  calories?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isNew?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isBestseller?: boolean;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  sortOrder?: number;

  @ApiProperty()
  @IsUUID()
  categoryId: string;
}

export class UpdateProductDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameKy?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  nameRu?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  descriptionKy?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  descriptionRu?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  price?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  discountPrice?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  images?: string[];

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  ingredients?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  weight?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  calories?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isAvailable?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isNew?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isBestseller?: boolean;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  sortOrder?: number;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  categoryId?: string;
}
