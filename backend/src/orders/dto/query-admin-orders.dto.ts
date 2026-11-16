import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { OrderStatus } from '@prisma/client';
import { parseBool } from '../../common/parse-bool';

export class QueryAdminOrdersDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional({ enum: OrderStatus })
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  @ApiPropertyOptional({
    description: 'Filter by store (admin only; staff always see their store)',
  })
  @IsOptional()
  @IsUUID()
  storeId?: string;

  @ApiPropertyOptional({
    description: 'Only orders without a store (delivery orders to assign)',
  })
  @IsOptional()
  @Transform(({ obj, key }) => parseBool(obj[key], false))
  @IsBoolean()
  unassigned?: boolean;

  @ApiPropertyOptional({ description: 'Created at or after (ISO date)' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ description: 'Created before (ISO date)' })
  @IsOptional()
  @IsDateString()
  to?: string;
}
