import { IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateUserDto {
  @ApiProperty({ example: 'John Smith', description: 'The updated name of the User', required: false })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ example: '+19876543210', description: 'The updated phone number of the User', required: false })
  @IsString()
  @IsOptional()
  phone?: string;
}
