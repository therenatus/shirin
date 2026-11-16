import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}

export class LogoutDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  refreshToken?: string;
}
