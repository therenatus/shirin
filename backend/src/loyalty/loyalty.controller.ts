import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { LoyaltyService } from './loyalty.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ClaimCoffeeDto } from './dto/claim-coffee.dto';

@ApiTags('Loyalty')
@Controller('loyalty')
export class LoyaltyController {
  constructor(private loyaltyService: LoyaltyService) {}

  @Get()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get loyalty info (points, qrCode, level)' })
  getLoyaltyInfo(@CurrentUser() user: any) {
    return this.loyaltyService.getBalance(user.id);
  }

  @Get('balance')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get loyalty points balance' })
  getBalance(@CurrentUser() user: any) {
    return this.loyaltyService.getBalance(user.id);
  }

  @Get('history')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get loyalty points history' })
  getHistory(@CurrentUser() user: any) {
    return this.loyaltyService.getHistory(user.id);
  }

  @Get('settings')
  @ApiOperation({ summary: 'Get loyalty program rules' })
  getSettings() {
    return this.loyaltyService.getSettings();
  }

  // ==================== PUNCH CARDS ====================

  @Get('punch-cards')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get all coffee punch cards for user' })
  getPunchCards(@CurrentUser() user: any) {
    return this.loyaltyService.getPunchCards(user.id);
  }

  // ==================== STAFF ====================

  @Get('staff/customer/:qrCode')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'SUPPORT', 'STORE_STAFF')
  @ApiOperation({ summary: 'Find customer and punch cards by QR code (Staff)' })
  @ApiParam({ name: 'qrCode', description: 'Customer QR code' })
  findCustomer(@Param('qrCode') qrCode: string) {
    return this.loyaltyService.findCustomerByQr(qrCode);
  }

  @Post('staff/claim')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'SUPPORT', 'STORE_STAFF')
  @ApiOperation({
    summary: 'Give out free coffee for a completed punch card (Staff)',
  })
  claimFreeCoffee(@Body() dto: ClaimCoffeeDto) {
    return this.loyaltyService.claimFreeCoffee(dto.qrCode, dto.size);
  }
}
