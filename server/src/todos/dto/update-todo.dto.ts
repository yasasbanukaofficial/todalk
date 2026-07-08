import { IsEnum, IsOptional, IsString, IsDateString, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Priority } from '../entities/todo.entity';

export class UpdateTodoDto {
  @ApiProperty({ example: 'Buy groceries and snacks', required: false })
  @IsString()
  @IsOptional()
  title?: string;

  @ApiProperty({ example: 'Milk, bread, fruits, and chocolate', required: false })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ example: true, required: false })
  @IsBoolean()
  @IsOptional()
  isCompleted?: boolean;

  @ApiProperty({ example: '2026-07-17T12:00:00.000Z', required: false })
  @IsDateString()
  @IsOptional()
  dueDate?: string;

  @ApiProperty({ enum: Priority, required: false })
  @IsEnum(Priority)
  @IsOptional()
  priority?: Priority;
}
