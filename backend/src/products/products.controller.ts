import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { ProductsService } from './products.service';
import { CreateProductDto, UpdateProductDto } from './dto/create-product.dto';
import { QueryProductsDto } from './dto/query-products.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(private productsService: ProductsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all products with filters' })
  findAll(@Query() query: QueryProductsDto) {
    return this.productsService.findAll(query);
  }

  @Get('categories')
  @ApiOperation({ summary: 'Get all categories with product counts' })
  getCategories() {
    return this.productsService.getCategories();
  }

  @Get('favorites')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get user favorites' })
  getFavorites(@CurrentUser() user: any) {
    return this.productsService.getFavorites(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get product details' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  findOne(@Param('id') id: string) {
    return this.productsService.findOne(id);
  }

  @Post(':id/favorite')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Toggle product favorite' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  toggleFavorite(@CurrentUser() user: any, @Param('id') productId: string) {
    return this.productsService.toggleFavorite(user.id, productId);
  }

  @Get(':id/favorite')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Check if product is favorite' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  checkFavorite(@CurrentUser() user: any, @Param('id') productId: string) {
    return this.productsService.checkFavorite(user.id, productId);
  }

  // Admin endpoints
  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Create product (Admin)' })
  create(@Body() dto: CreateProductDto) {
    return this.productsService.create(dto);
  }

  @Patch(':id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Update product (Admin)' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  update(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.productsService.update(id, dto);
  }

  @Delete(':id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Delete product (Admin)' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  delete(@Param('id') id: string) {
    return this.productsService.delete(id);
  }
}
