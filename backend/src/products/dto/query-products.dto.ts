import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsString,
  IsNumber,
  IsEnum,
  IsUUID,
  Min,
  Max,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { parseBool } from '../../common/parse-bool';

export enum ProductSortBy {
  PRICE_ASC = 'price_asc',
  PRICE_DESC = 'price_desc',
  NAME_ASC = 'name_asc',
  NAME_DESC = 'name_desc',
  NEWEST = 'newest',
  POPULAR = 'popular',
}

export class QueryProductsDto {
  @ApiPropertyOptional()
  @IsUUID()
  @IsOptional()
  categoryId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  search?: string;

  @ApiPropertyOptional({ enum: ProductSortBy })
  @IsEnum(ProductSortBy)
  @IsOptional()
  sortBy?: ProductSortBy;

  @ApiPropertyOptional({ default: 1 })
  @Transform(({ value }) => parseInt(value, 10))
  @IsNumber()
  @Min(1)
  @IsOptional()
  page?: number = 1;

  @ApiPropertyOptional({ default: 20, maximum: 100 })
  @Transform(({ value }) => parseInt(value, 10))
  @IsNumber()
  @Min(1)
  @Max(100)
  @IsOptional()
  limit?: number = 20;

  @ApiPropertyOptional()
  @Transform(({ obj, key }) => parseBool(obj[key], false) || undefined)
  @IsOptional()
  isNew?: boolean;

  @ApiPropertyOptional()
  @Transform(({ obj, key }) => parseBool(obj[key], false) || undefined)
  @IsOptional()
  isBestseller?: boolean;

  @ApiPropertyOptional()
  @Transform(({ obj, key }) => parseBool(obj[key], false) || undefined)
  @IsOptional()
  hasDiscount?: boolean;

  @ApiPropertyOptional({ description: 'Minimum price filter' })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  minPrice?: number;

  @ApiPropertyOptional({ description: 'Maximum price filter' })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  @IsOptional()
  maxPrice?: number;
}
