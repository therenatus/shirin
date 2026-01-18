import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { SendCodeDto } from './dto/send-code.dto';
import { VerifyCodeDto } from './dto/verify-code.dto';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async sendCode(dto: SendCodeDto) {
    const code = this.generateCode();

    // TODO: Integrate SMS service (Nikita, Beeline)
    // await this.smsService.send(dto.phone, `Your code: ${code}`);

    // For development, log code to console
    console.log(`SMS Code for ${dto.phone}: ${code}`);

    // TODO: Save code to Redis with TTL 5 minutes
    // await this.redis.set(`sms:${dto.phone}`, code, 'EX', 300);

    return {
      success: true,
      message: `Code sent to ${dto.phone}`,
    };
  }

  async verifyCode(dto: VerifyCodeDto) {
    // TODO: Verify code from Redis
    // const storedCode = await this.redis.get(`sms:${dto.phone}`);

    // For development, accept any 4-digit code
    if (dto.code.length !== 4) {
      throw new BadRequestException('Invalid code');
    }

    let user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phone: dto.phone,
          qrCode: this.generateQRCode(),
        },
      });
    }

    // Update lastLoginAt
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const tokens = await this.generateTokens(user.id);

    return {
      user: {
        id: user.id,
        phone: user.phone,
        firstName: user.firstName,
        lastName: user.lastName,
        loyaltyPoints: user.loyaltyPoints,
        qrCode: user.qrCode,
      },
      ...tokens,
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const tokens = await this.generateTokens(payload.sub);
      return tokens;
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string) {
    // TODO: Add refresh token to blacklist (Redis)
    return { success: true };
  }

  private async generateTokens(userId: string) {
    const payload = { sub: userId };

    const accessToken = this.jwtService.sign(payload, {
      expiresIn: '7d',
    });

    const refreshToken = this.jwtService.sign(payload, {
      expiresIn: '30d',
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  private generateCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  private generateQRCode(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 11);
    return `SHR-${timestamp}-${random}`;
  }
}
