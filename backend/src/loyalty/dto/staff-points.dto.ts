import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { LoyaltyTxSource, LoyaltyTxType } from '@prisma/client';

class ReceiptDto {
  @ApiProperty({
    description: 'Customer QR code or one-time token from the app',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  code: string;

  @ApiProperty({ description: 'Receipt number from the cash register' })
  @IsString()
  @Matches(/^[\w\-/.]{1,40}$/, {
    message: 'receiptNumber: letters, digits, - / . up to 40 characters',
  })
  receiptNumber: string;

  @ApiProperty({ description: 'Receipt total in som' })
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(10_000_000)
  receiptAmount: number;

  @ApiPropertyOptional({
    description: 'Store of the cash desk (admins only; staff use their own)',
  })
  @IsOptional()
  @IsUUID()
  storeId?: string;
}

export class EarnPointsDto extends ReceiptDto {}

export class RedeemPointsDto extends ReceiptDto {
  @ApiProperty({ description: 'Points to spend (1 point = 1 som)' })
  @IsInt()
  @Min(1)
  points: number;
}

export class ReverseTransactionDto {
  @ApiPropertyOptional({ description: 'Why the operation is cancelled' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  reason?: string;
}

export class QueryTransactionsDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(200)
  limit?: number = 50;

  @ApiPropertyOptional({ description: 'Admins only; staff see their store' })
  @IsOptional()
  @IsUUID()
  storeId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  staffId?: string;

  @ApiPropertyOptional({ enum: LoyaltyTxSource })
  @IsOptional()
  @IsEnum(LoyaltyTxSource)
  source?: LoyaltyTxSource;

  @ApiPropertyOptional({ enum: LoyaltyTxType })
  @IsOptional()
  @IsEnum(LoyaltyTxType)
  type?: LoyaltyTxType;

  @ApiPropertyOptional({ description: 'From (ISO date, inclusive)' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ description: 'To (ISO date, exclusive)' })
  @IsOptional()
  @IsDateString()
  to?: string;
}
