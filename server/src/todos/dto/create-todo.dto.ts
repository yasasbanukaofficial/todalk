import { IsEnum, IsNotEmpty, IsOptional, IsString, IsDateString, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Priority } from '../entities/todo.entity';

export class CreateTodoDto {
  @ApiProperty({ example: 'Buy groceries' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'Milk, bread, and fruits', required: false })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ example: false, required: false })
  @IsBoolean()
  @IsOptional()
  isCompleted?: boolean;

  @ApiProperty({ example: '2026-07-16T12:00:00.000Z', required: false })
  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @ApiProperty({ enum: Priority, default: Priority.MEDIUM, required: false })
  @IsEnum(Priority)
  @IsOptional()
  priority?: Priority;
}
