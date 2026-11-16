import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { PromotionType } from '@prisma/client';

export class CreatePromotionDto {
  @ApiProperty() @IsString() @MinLength(1) @MaxLength(120) titleRu: string;
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  titleKy?: string;
  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  descriptionRu: string;
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  descriptionKy?: string;

  @ApiProperty({
    description: 'Banner image URL (POST /storage/upload?folder=promotions)',
  })
  @IsUrl({ require_tld: false })
  @MaxLength(500)
  image: string;

  @ApiProperty({ enum: PromotionType })
  @IsEnum(PromotionType)
  type: PromotionType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  discountPercent?: number;
  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  cashbackPercent?: number;
  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  minOrderAmount?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  productIds?: string[];

  @ApiProperty() @IsDateString() startDate: string;
  @ApiProperty() @IsDateString() endDate: string;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isActive?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(0) sortOrder?: number;
}

export class UpdatePromotionDto extends PartialType(CreatePromotionDto) {}
