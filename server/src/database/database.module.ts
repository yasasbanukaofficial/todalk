import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { User } from '../users/entities/user.entity';
import { Todo } from '../todos/entities/todo.entity';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const url = configService.get<string>('DATABASE_URL');
        const isNeon = url?.includes('neon.tech') || url?.includes('sslmode=require');

        return {
          type: 'postgres',
          url,
          entities: [User, Todo],
          // In production/deployment, synchronize: true is not recommended, but for simplicity of Neon deployment,
          // synchronize: true is extremely convenient, or we can use migrations. Let's set auto-sync for simplicity.
          synchronize: true,
          ssl: isNeon ? { rejectUnauthorized: false } : false,
        };
      },
    }),
  ],
})
export class DatabaseModule {}
