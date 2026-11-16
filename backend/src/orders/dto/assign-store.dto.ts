import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class AssignStoreDto {
  @ApiProperty({ description: 'Store that will fulfil the order' })
  @IsUUID()
  storeId: string;
}
