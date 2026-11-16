import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { PaymentMethod } from '@prisma/client';

/** Methods staff can confirm by hand; BANK comes only from the bank. */
const STAFF_METHODS = [PaymentMethod.MANUAL_QR, PaymentMethod.CASH] as const;

export class ConfirmPaymentDto {
  @ApiProperty({ enum: STAFF_METHODS })
  @IsIn(STAFF_METHODS)
  method: (typeof STAFF_METHODS)[number];

  @ApiPropertyOptional({ description: 'E.g. payer name or transfer number' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}

export class RefundPaymentDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}
