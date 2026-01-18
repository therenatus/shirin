import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { LoyaltyService } from './loyalty.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Loyalty')
@Controller('loyalty')
export class LoyaltyController {
  constructor(private loyaltyService: LoyaltyService) {}

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
}
