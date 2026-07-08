import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { TodosService } from './todos.service';
import { CreateTodoDto } from './dto/create-todo.dto';
import { UpdateTodoDto } from './dto/update-todo.dto';
import { QueryTodoDto } from './dto/query-todo.dto';
import { TodoResponseDto } from './dto/todo-response.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ApiBearerAuth, ApiOkResponse, ApiCreatedResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('todos')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('todos')
export class TodosController {
  constructor(private readonly todosService: TodosService) {}

  @Post()
  @ApiCreatedResponse({ type: TodoResponseDto })
  async create(
    @CurrentUser('id') userId: string,
    @Body() createTodoDto: CreateTodoDto,
  ): Promise<TodoResponseDto> {
    const todo = await this.todosService.create(userId, createTodoDto);
    return this.mapToResponse(todo);
  }

  @Get()
  @ApiOkResponse({ type: [TodoResponseDto] })
  async findAll(
    @CurrentUser('id') userId: string,
    @Query() query: QueryTodoDto,
  ) {
    const { page, limit, isCompleted, priority } = query;
    const result = await this.todosService.findAll(userId, {
      isCompleted,
      priority,
      page,
      limit,
    });

    return {
      data: result.data.map((todo) => this.mapToResponse(todo)),
      meta: result.meta,
    };
  }

  @Get(':id')
  @ApiOkResponse({ type: TodoResponseDto })
  async findOne(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ): Promise<TodoResponseDto> {
    const todo = await this.todosService.findOne(userId, id);
    return this.mapToResponse(todo);
  }

  @Patch(':id')
  @ApiOkResponse({ type: TodoResponseDto })
  async update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() updateTodoDto: UpdateTodoDto,
  ): Promise<TodoResponseDto> {
    const todo = await this.todosService.update(userId, id, updateTodoDto);
    return this.mapToResponse(todo);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ): Promise<void> {
    await this.todosService.remove(userId, id);
  }

  private mapToResponse(todo: any): TodoResponseDto {
    return {
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: todo.isCompleted,
      dueDate: todo.dueDate,
      priority: todo.priority,
      userId: todo.userId,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
    };
  }
}
