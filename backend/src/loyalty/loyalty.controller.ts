import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
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
import {
  EarnPointsDto,
  QueryTransactionsDto,
  RedeemPointsDto,
  ReverseTransactionDto,
} from './dto/staff-points.dto';
import type { AuthUser } from '../auth/types/auth-user';

@ApiTags('Loyalty')
@Controller('loyalty')
export class LoyaltyController {
  constructor(private loyaltyService: LoyaltyService) {}

  @Get()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get loyalty info (points, qrCode, level)' })
  getLoyaltyInfo(@CurrentUser() user: AuthUser) {
    return this.loyaltyService.getBalance(user.id);
  }

  @Get('balance')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get loyalty points balance' })
  getBalance(@CurrentUser() user: AuthUser) {
    return this.loyaltyService.getBalance(user.id);
  }

  @Get('history')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get loyalty points history' })
  getHistory(@CurrentUser() user: AuthUser) {
    return this.loyaltyService.getHistory(user.id);
  }

  @Get('settings')
  @ApiOperation({ summary: 'Get loyalty program rules' })
  getSettings() {
    return this.loyaltyService.getSettings();
  }

  @Get('qr-token')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'One-time QR code for the cash desk (valid 60 s, refresh in app)',
  })
  getQrToken(@CurrentUser() user: AuthUser) {
    return this.loyaltyService.issueQrToken(user.id);
  }

  // ==================== PUNCH CARDS ====================

  @Get('punch-cards')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get all coffee punch cards for user' })
  getPunchCards(@CurrentUser() user: AuthUser) {
    return this.loyaltyService.getPunchCards(user.id);
  }

  // ==================== STAFF (CASH DESK) ====================

  @Get('staff/customer/:code')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'SUPPORT', 'STORE_STAFF')
  @ApiOperation({
    summary: 'Find customer by QR code or one-time token (Staff)',
  })
  @ApiParam({ name: 'code', description: 'QR code or one-time token' })
  findCustomer(@Param('code') code: string) {
    return this.loyaltyService.findCustomer(code);
  }

  @Post('staff/claim')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'SUPPORT', 'STORE_STAFF')
  @ApiOperation({
    summary: 'Give out free coffee for a completed punch card (Staff)',
  })
  claimFreeCoffee(@CurrentUser() user: AuthUser, @Body() dto: ClaimCoffeeDto) {
    return this.loyaltyService.claimFreeCoffee(user, dto.qrCode, dto.size);
  }

  @Post('staff/earn')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'STORE_STAFF')
  @ApiOperation({ summary: 'Credit cashback for an in-store purchase (Staff)' })
  earn(@CurrentUser() user: AuthUser, @Body() dto: EarnPointsDto) {
    return this.loyaltyService.earnInStore(user, dto);
  }

  @Post('staff/redeem')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'STORE_STAFF')
  @ApiOperation({
    summary:
      'Pay part of an in-store purchase with points (Staff, live QR only)',
  })
  redeem(@CurrentUser() user: AuthUser, @Body() dto: RedeemPointsDto) {
    return this.loyaltyService.redeemInStore(user, dto);
  }

  @Get('staff/transactions')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'STORE_STAFF')
  @ApiOperation({
    summary: 'Loyalty operations report (Admin: all, store staff: own store)',
  })
  listTransactions(
    @CurrentUser() user: AuthUser,
    @Query() query: QueryTransactionsDto,
  ) {
    return this.loyaltyService.listTransactions(user, query);
  }

  @Post('staff/transactions/:id/reverse')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Cancel a loyalty operation (Admin)' })
  reverse(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReverseTransactionDto,
  ) {
    return this.loyaltyService.reverseTransaction(user, id, dto.reason);
  }
}
