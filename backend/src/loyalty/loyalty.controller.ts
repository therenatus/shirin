import { Controller, Get, Post, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { LoyaltyService } from './loyalty.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CoffeeSize } from '@prisma/client';

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

  @Post('punch-cards/:size/claim')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Claim free coffee for completed punch card' })
  @ApiParam({ name: 'size', enum: ['S', 'M', 'L'], description: 'Coffee size' })
  claimFreeCoffee(@CurrentUser() user: any, @Param('size') size: CoffeeSize) {
    return this.loyaltyService.claimFreeCoffee(user.id, size);
  }
}
