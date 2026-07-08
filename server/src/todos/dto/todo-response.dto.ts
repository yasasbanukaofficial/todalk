import { ApiProperty } from '@nestjs/swagger';
import { Priority } from '../entities/todo.entity';

export class TodoResponseDto {
  @ApiProperty({ example: '85f95886-dfce-4fc3-a9cf-f9a263c9b8b8' })
  id: string;

  @ApiProperty({ example: 'Buy groceries' })
  title: string;

  @ApiProperty({ example: 'Milk and bread', nullable: true })
  description: string | null;

  @ApiProperty({ example: false })
  isCompleted: boolean;

  @ApiProperty({ example: '2026-07-16T12:00:00.000Z', nullable: true })
  dueDate: Date | null;

  @ApiProperty({ enum: Priority, example: Priority.MEDIUM })
  priority: Priority;

  @ApiProperty({ example: 'user-id-uuid-string' })
  userId: string;

  @ApiProperty({ example: '2026-07-15T00:00:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2026-07-15T00:00:00.000Z' })
  updatedAt: Date;
}
