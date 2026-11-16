import { plainToInstance } from 'class-transformer';
import { QueryAdminOrdersDto } from '../orders/dto/query-admin-orders.dto';
import { QueryStaffDto } from '../users/dto/staff.dto';
import { QueryProductsDto } from '../products/dto/query-products.dto';

// Same options as the global ValidationPipe in main.ts
const parse = <T>(cls: new () => T, query: Record<string, string>) =>
  plainToInstance(cls, query, { enableImplicitConversion: true });

describe('boolean query parameters', () => {
  it('reads "false" as false despite implicit conversion', () => {
    expect(parse(QueryStaffDto, { staffOnly: 'false' }).staffOnly).toBe(false);
    expect(parse(QueryAdminOrdersDto, { unassigned: 'false' }).unassigned).toBe(false);
  });

  it('reads "true" as true and applies defaults', () => {
    expect(parse(QueryAdminOrdersDto, { unassigned: 'true' }).unassigned).toBe(true);
    expect(parse(QueryStaffDto, {}).staffOnly).toBe(true);
  });

  it('turns product flags into filters only when true', () => {
    expect(parse(QueryProductsDto, { isNew: 'true' }).isNew).toBe(true);
    expect(parse(QueryProductsDto, { isNew: 'false' }).isNew).toBeUndefined();
  });
});
