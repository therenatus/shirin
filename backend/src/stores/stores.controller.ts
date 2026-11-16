import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { StoresService } from './stores.service';
import { CreateStoreDto, UpdateStoreDto } from './dto/create-store.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('Stores')
@Controller('stores')
export class StoresController {
  constructor(private storesService: StoresService) {}

  @Get()
  @ApiOperation({ summary: 'Get all active stores' })
  findAll() {
    return this.storesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get store details' })
  @ApiParam({ name: 'id', description: 'Store ID' })
  findOne(@Param('id') id: string) {
    return this.storesService.findOne(id);
  }

  // Admin endpoints
  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Create store (Admin)' })
  create(@Body() dto: CreateStoreDto) {
    return this.storesService.create(dto);
  }

  @Patch(':id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Update store (Admin)' })
  @ApiParam({ name: 'id', description: 'Store ID' })
  update(@Param('id') id: string, @Body() dto: UpdateStoreDto) {
    return this.storesService.update(id, dto);
  }

  @Delete(':id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Deactivate store (Admin)' })
  @ApiParam({ name: 'id', description: 'Store ID' })
  remove(@Param('id') id: string) {
    return this.storesService.remove(id);
  }
}
