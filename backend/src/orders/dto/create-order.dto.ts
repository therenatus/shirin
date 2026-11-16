import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsArray,
  IsInt,
  ArrayMinSize,
  ArrayMaxSize,
  IsUrl,
  Max,
  MaxLength,
  IsUUID,
  IsEnum,
  ValidateNested,
  Min,
  IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum DeliveryType {
  DELIVERY = 'delivery',
  PICKUP = 'pickup',
}

export class OrderItemDto {
  @ApiProperty({ description: 'Product ID' })
  @IsUUID()
  productId: string;

  @ApiProperty({ description: 'Quantity', minimum: 1, maximum: 50 })
  @IsInt()
  @Min(1)
  @Max(50)
  quantity: number;

  @ApiPropertyOptional({
    description: 'Text on the cake (only if the product allows it)',
  })
  @IsString()
  @MaxLength(60)
  @IsOptional()
  inscription?: string;

  @ApiPropertyOptional({ description: 'Wishes for this item' })
  @IsString()
  @MaxLength(300)
  @IsOptional()
  wishes?: string;

  @ApiPropertyOptional({
    description: 'Reference photo URL from POST /storage/reference-photo',
  })
  @IsUrl({ require_tld: false })
  @MaxLength(500)
  @IsOptional()
  referencePhotoUrl?: string;
}

export class CreateOrderDto {
  @ApiProperty({ type: [OrderItemDto], description: 'Order items' })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(30)
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @ApiProperty({ enum: DeliveryType, description: 'Delivery type' })
  @IsEnum(DeliveryType)
  deliveryType: DeliveryType;

  @ApiPropertyOptional({ description: 'Address ID (required for delivery)' })
  @IsUUID()
  @IsOptional()
  addressId?: string;

  @ApiPropertyOptional({ description: 'Store ID (required for pickup)' })
  @IsUUID()
  @IsOptional()
  storeId?: string;

  @ApiPropertyOptional({ description: 'Desired delivery/pickup time' })
  @IsDateString()
  @IsOptional()
  deliveryTime?: string;

  @ApiPropertyOptional({ description: 'Order comment' })
  @IsString()
  @MaxLength(500)
  @IsOptional()
  comment?: string;

  @ApiPropertyOptional({ description: 'Loyalty points to use' })
  @IsInt()
  @Min(0)
  @Max(1_000_000)
  @IsOptional()
  pointsToUse?: number;
}
