import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { SendCodeDto } from './dto/send-code.dto';
import { VerifyCodeDto } from './dto/verify-code.dto';
import { RefreshTokenDto, LogoutDto } from './dto/refresh-token.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private usersService: UsersService,
  ) {}

  @Post('send-code')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Send SMS code' })
  sendCode(@Body() dto: SendCodeDto) {
    return this.authService.sendCode(dto);
  }

  @Post('verify-code')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Verify SMS code and login' })
  verifyCode(@Body() dto: VerifyCodeDto) {
    return this.authService.verifyCode(dto);
  }

  @Post('refresh')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Refresh access token' })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto.refreshToken);
  }

  @Post('logout')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Logout' })
  logout(@CurrentUser() user: any, @Body() dto: LogoutDto) {
    return this.authService.logout(user.id, dto.refreshToken);
  }

  @Get('profile')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Get current user profile' })
  getProfile(@CurrentUser() user: any) {
    return this.usersService.findById(user.id);
  }
}
