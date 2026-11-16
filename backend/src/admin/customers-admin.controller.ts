import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiProperty,
  ApiPropertyOptional,
  ApiTags,
} from '@nestjs/swagger';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { parseBool } from '../common/parse-bool';
import { CustomersAdminService } from './customers-admin.service';

class CustomersQuery {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(50)
  search?: string;

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

  @ApiPropertyOptional({
    description: 'true: only blocked, false: only active',
  })
  @IsOptional()
  @Transform(({ obj, key }) =>
    obj[key] === undefined ? undefined : parseBool(obj[key], false),
  )
  @IsBoolean()
  blocked?: boolean;
}

class BlockDto {
  @ApiProperty() @IsBoolean() blocked: boolean;
}

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
@Controller('admin/customers')
export class CustomersAdminController {
  constructor(private customers: CustomersAdminService) {}

  @Get()
  @ApiOperation({ summary: 'Customers with order stats (Admin)' })
  list(@Query() q: CustomersQuery) {
    return this.customers.list(q);
  }

  @Patch(':id/block')
  @ApiOperation({ summary: 'Block or unblock a customer (Admin)' })
  block(@Param('id', ParseUUIDPipe) id: string, @Body() dto: BlockDto) {
    return this.customers.setBlocked(id, dto.blocked);
  }
}
