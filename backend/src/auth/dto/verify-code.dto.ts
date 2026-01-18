import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length, Matches } from 'class-validator';

export class VerifyCodeDto {
  @ApiProperty({ example: '+996700123456' })
  @IsString()
  @Matches(/^\+996[0-9]{9}$/, { message: 'Invalid Kyrgyz phone number' })
  phone: string;

  @ApiProperty({ example: '1234' })
  @IsString()
  @Length(4, 4)
  code: string;
}
