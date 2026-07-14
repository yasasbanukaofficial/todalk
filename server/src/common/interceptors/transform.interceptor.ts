import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Response<T> {
  success: boolean;
  data: T;
  meta?: any;
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, Response<T>> {
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<Response<T>> {
    return next.handle().pipe(
      map((value) => {
        // If already formatted, return as-is
        if (value && typeof value === 'object' && 'success' in value) {
          return value;
        }

        // If the controller returned a paginated response like { data, meta }
        if (value && typeof value === 'object' && 'data' in value && 'meta' in value) {
          return {
            success: true,
            data: value.data,
            meta: value.meta,
          };
        }

        return {
          success: true,
          data: value === undefined ? null : value,
        };
      }),
    );
  }
}
