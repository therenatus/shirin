import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Post,
  Param,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import type { AuthUser } from '../auth/types/auth-user';
import { QueryStaffDto, UpdateUserRoleDto } from './dto/staff.dto';
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

  // ==================== STAFF (ADMIN) ====================

  @Get('admin/staff')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'List employees or search users (Admin)' })
  findStaff(@Query() query: QueryStaffDto) {
    return this.usersService.findStaff(query);
  }

  @Patch('admin/:id/role')
  @UseGuards(RolesGuard)
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Set user role and store (Admin)' })
  updateRole(
    @CurrentUser() actor: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserRoleDto,
  ) {
    return this.usersService.updateRole(actor.id, id, dto);
  }
}
