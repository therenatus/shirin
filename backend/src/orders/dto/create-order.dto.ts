import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsArray,
  IsInt,
  ArrayMinSize,
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

  @ApiProperty({ description: 'Quantity', minimum: 1 })
  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @ApiProperty({ type: [OrderItemDto], description: 'Order items' })
  @IsArray()
  @ArrayMinSize(1)
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
  @IsOptional()
  comment?: string;

  @ApiPropertyOptional({ description: 'Loyalty points to use' })
  @IsInt()
  @Min(0)
  @IsOptional()
  pointsToUse?: number;
}
