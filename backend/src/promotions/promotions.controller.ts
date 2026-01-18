import { Controller, Get, Post, Param, UseGuards, Req, Injectable } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { PromotionsService } from './promotions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthGuard } from '@nestjs/passport';

// Optional auth guard that doesn't fail on missing token
@Injectable()
class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  handleRequest(_err: Error | null, user: any) {
    return user || null;
  }
}

@ApiTags('Promotions')
@Controller()
export class PromotionsController {
  constructor(private promotionsService: PromotionsService) {}

  @Get('promotions')
  @ApiOperation({ summary: 'Get all active promotions' })
  findAllPromotions() {
    return this.promotionsService.findAllPromotions();
  }

  @Get('promotions/:id')
  @ApiOperation({ summary: 'Get promotion details' })
  @ApiParam({ name: 'id', description: 'Promotion ID' })
  findOnePromotion(@Param('id') id: string) {
    return this.promotionsService.findOnePromotion(id);
  }

  @Get('raffles')
  @ApiOperation({ summary: 'Get all active raffles' })
  findAllRaffles() {
    return this.promotionsService.findAllRaffles();
  }

  @Get('raffles/:id')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Get raffle details' })
  @ApiParam({ name: 'id', description: 'Raffle ID' })
  findOneRaffle(@Param('id') id: string, @Req() req: any) {
    const userId = req.user?.id;
    return this.promotionsService.findOneRaffle(id, userId);
  }

  @Post('raffles/:id/enter')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Enter raffle' })
  @ApiParam({ name: 'id', description: 'Raffle ID' })
  enterRaffle(@CurrentUser() user: any, @Param('id') raffleId: string) {
    return this.promotionsService.enterRaffle(user.id, raffleId);
  }
}
