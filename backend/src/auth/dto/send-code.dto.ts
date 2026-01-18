import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

export class SendCodeDto {
  @ApiProperty({ example: '+996700123456' })
  @IsString()
  @Matches(/^\+996[0-9]{9}$/, { message: 'Invalid Kyrgyz phone number' })
  phone: string;
}
