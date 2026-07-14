import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateTodoDto } from './dto/create-todo.dto';
import { UpdateTodoDto } from './dto/update-todo.dto';
import { Todo, Priority } from './entities/todo.entity';

@Injectable()
export class TodosService {
  constructor(
    @InjectRepository(Todo)
    private readonly todoRepository: Repository<Todo>,
  ) {}

  async create(userId: string, createTodoDto: CreateTodoDto): Promise<Todo> {
    const todo = this.todoRepository.create({
      ...createTodoDto,
      userId,
    });
    return this.todoRepository.save(todo);
  }

  async findAll(
    userId: string,
    filters: {
      isCompleted?: boolean;
      priority?: Priority;
      page?: number;
      limit?: number;
    },
  ) {
    const { isCompleted, priority, page = 1, limit = 20 } = filters;
    const skip = (page - 1) * limit;

    const where: any = { userId };

    if (isCompleted !== undefined) {
      where.isCompleted = isCompleted;
    }

    if (priority !== undefined) {
      where.priority = priority;
    }

    const [todos, total] = await this.todoRepository.findAndCount({
      where,
      skip,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return {
      data: todos,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(userId: string, id: string): Promise<Todo> {
    const todo = await this.todoRepository.findOne({
      where: { id },
    });

    if (!todo) {
      throw new NotFoundException('Todo not found');
    }

    if (todo.userId !== userId) {
      throw new ForbiddenException('You do not have permission to access this todo');
    }

    return todo;
  }

  async update(userId: string, id: string, updateTodoDto: UpdateTodoDto): Promise<Todo> {
    // Validate ownership first
    const todo = await this.findOne(userId, id);

    Object.assign(todo, updateTodoDto);

    return this.todoRepository.save(todo);
  }

  async remove(userId: string, id: string): Promise<void> {
    // Validate ownership first
    const todo = await this.findOne(userId, id);

    await this.todoRepository.remove(todo);
  }
}
