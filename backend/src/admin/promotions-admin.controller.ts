import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { PromotionsAdminService } from './promotions-admin.service';
import { CreatePromotionDto, UpdatePromotionDto } from './dto/promotion.dto';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
@Controller('admin/promotions')
export class PromotionsAdminController {
  constructor(private promotions: PromotionsAdminService) {}

  @Get()
  @ApiOperation({ summary: 'All promotions incl. inactive and past (Admin)' })
  findAll() {
    return this.promotions.findAll();
  }

  @Post()
  @ApiOperation({ summary: 'Create a promotion banner (Admin)' })
  create(@Body() dto: CreatePromotionDto) {
    return this.promotions.create(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a promotion (Admin)' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePromotionDto,
  ) {
    return this.promotions.update(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a promotion (Admin)' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.promotions.remove(id);
  }
}
