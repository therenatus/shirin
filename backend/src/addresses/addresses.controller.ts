import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { AddressesService } from './addresses.service';
import { CreateAddressDto, UpdateAddressDto } from './dto/create-address.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Addresses')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('addresses')
export class AddressesController {
  constructor(private addressesService: AddressesService) {}

  @Get()
  @ApiOperation({ summary: 'Get user addresses' })
  findAll(@CurrentUser() user: any) {
    return this.addressesService.findAll(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get address details' })
  @ApiParam({ name: 'id', description: 'Address ID' })
  findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.addressesService.findOne(user.id, id);
  }

  @Post()
  @ApiOperation({ summary: 'Create new address' })
  create(@CurrentUser() user: any, @Body() dto: CreateAddressDto) {
    return this.addressesService.create(user.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update address' })
  @ApiParam({ name: 'id', description: 'Address ID' })
  update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateAddressDto,
  ) {
    return this.addressesService.update(user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete address' })
  @ApiParam({ name: 'id', description: 'Address ID' })
  delete(@CurrentUser() user: any, @Param('id') id: string) {
    return this.addressesService.delete(user.id, id);
  }

  @Post(':id/default')
  @ApiOperation({ summary: 'Set address as default' })
  @ApiParam({ name: 'id', description: 'Address ID' })
  setDefault(@CurrentUser() user: any, @Param('id') id: string) {
    return this.addressesService.setDefault(user.id, id);
  }
}
