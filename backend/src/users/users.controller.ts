import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Post,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user' })
  getMe(@CurrentUser() user: any) {
    return this.usersService.findById(user.id);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update profile' })
  updateProfile(@CurrentUser() user: any, @Body() dto: UpdateUserDto) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Get('me/qr-code')
  @ApiOperation({ summary: 'Get QR code' })
  getQRCode(@CurrentUser() user: any) {
    return this.usersService.getQRCode(user.id);
  }

  @Post('me/fcm-token')
  @ApiOperation({ summary: 'Save FCM token' })
  updateFCMToken(@CurrentUser() user: any, @Body('token') token: string) {
    return this.usersService.updateFCMToken(user.id, token);
  }
}
