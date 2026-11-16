import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsArray,
  IsUUID,
  IsInt,
  Min,
  Max,
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

  @ApiPropertyOptional({ description: 'Made to order (custom cake)' })
  @IsBoolean()
  @IsOptional()
  isPreorder?: boolean;

  @ApiPropertyOptional({ description: 'Hours needed to make it (0-720)' })
  @IsInt()
  @Min(0)
  @Max(720)
  @IsOptional()
  leadTimeHours?: number;

  @ApiPropertyOptional({ description: 'Prepayment, % of the item total' })
  @IsInt()
  @Min(0)
  @Max(100)
  @IsOptional()
  prepaymentPercent?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  allowInscription?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  allowReferencePhoto?: boolean;

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

  @ApiPropertyOptional({ description: 'Made to order (custom cake)' })
  @IsBoolean()
  @IsOptional()
  isPreorder?: boolean;

  @ApiPropertyOptional({ description: 'Hours needed to make it (0-720)' })
  @IsInt()
  @Min(0)
  @Max(720)
  @IsOptional()
  leadTimeHours?: number;

  @ApiPropertyOptional({ description: 'Prepayment, % of the item total' })
  @IsInt()
  @Min(0)
  @Max(100)
  @IsOptional()
  prepaymentPercent?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  allowInscription?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  allowReferencePhoto?: boolean;

  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  categoryId?: string;
}
