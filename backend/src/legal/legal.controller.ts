import { Controller, Get, Header } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { renderPrivacyPolicy } from './privacy-policy';

/** Public pages the app stores link to; served without the /api/v1 prefix. */
@ApiExcludeController()
@Controller()
export class LegalController {
  @Get('privacy')
  @Header('Content-Type', 'text/html; charset=utf-8')
  @Header('Cache-Control', 'public, max-age=3600')
  privacy() {
    return renderPrivacyPolicy(process.env.PRIVACY_CONTACT_EMAIL ?? '');
  }
}
