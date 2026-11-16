import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { UserRole } from '@prisma/client';
import { parseBool } from '../../common/parse-bool';

export class QueryStaffDto {
  @ApiPropertyOptional({ description: 'Part of phone number or name' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  search?: string;

  @ApiPropertyOptional({
    description: 'Only employees (default). false searches all users',
    default: true,
  })
  @IsOptional()
  @Transform(({ obj, key }) => parseBool(obj[key], true))
  @IsBoolean()
  staffOnly?: boolean = true;
}

export class UpdateUserRoleDto {
  @ApiProperty({ enum: UserRole })
  @IsEnum(UserRole)
  role: UserRole;

  @ApiPropertyOptional({ description: 'Required for STORE_STAFF' })
  @IsOptional()
  @IsUUID()
  storeId?: string;
}
