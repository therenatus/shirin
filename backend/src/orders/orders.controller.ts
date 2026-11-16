import {
  Controller,
  Get,
  Post,
  Patch,
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
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { QueryAdminOrdersDto } from './dto/query-admin-orders.dto';
import { AssignStoreDto } from './dto/assign-store.dto';
import type { AuthUser } from '../auth/types/auth-user';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('orders')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  @Post()
  @ApiOperation({ summary: 'Create new order' })
  create(@CurrentUser() user: any, @Body() dto: CreateOrderDto) {
    return this.ordersService.create(user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get user orders' })
  findAll(@CurrentUser() user: any) {
    return this.ordersService.findAllByUser(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get order details' })
  @ApiParam({ name: 'id', description: 'Order ID' })
  findOne(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.ordersService.findOne(user, id);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel order' })
  @ApiParam({ name: 'id', description: 'Order ID' })
  cancel(@CurrentUser() user: any, @Param('id') id: string) {
    return this.ordersService.cancel(user.id, id);
  }

  // Staff endpoints: admins see every order, store staff only their store
  @Patch(':id/status')
  @UseGuards(RolesGuard)
  @Roles('ADMIN', 'STORE_STAFF')
  @ApiOperation({ summary: 'Update order status (Admin, store staff)' })
  @ApiParam({ name: 'id', description: 'Order ID' })
  updateStatus(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.ordersService.updateStatus(user, id, dto.status);
  }

  @Patch(':id/store')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Assign the store that fulfils the order (Admin)' })
  @ApiParam({ name: 'id', description: 'Order ID' })
  assignStore(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: AssignStoreDto,
  ) {
    return this.ordersService.assignStore(user, id, dto.storeId);
  }

  @Get('admin/all')
  @UseGuards(RolesGuard)
  @Roles('ADMIN', 'STORE_STAFF')
  @ApiOperation({ summary: 'List orders (Admin: all, store staff: own store)' })
  findAllAdmin(
    @CurrentUser() user: AuthUser,
    @Query() query: QueryAdminOrdersDto,
  ) {
    return this.ordersService.findAllAdmin(user, query);
  }
}
