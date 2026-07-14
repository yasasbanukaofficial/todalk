import { ApiProperty } from '@nestjs/swagger';

export class UserResponseDto {
  @ApiProperty({ example: '85f95886-dfce-4fc3-a9cf-f9a263c9b8b8' })
  id: string;

  @ApiProperty({ example: 'user@example.com' })
  email: string;

  @ApiProperty({ example: 'John Doe' })
  name: string;

  @ApiProperty({ example: '+1234567890', nullable: true })
  phone: string | null;

  @ApiProperty({ example: '2026-07-15T00:00:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2026-07-15T00:00:00.000Z' })
  updatedAt: Date;
}
