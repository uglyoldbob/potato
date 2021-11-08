#include <ctype.h>

#include <stdint.h>
#include <stdio.h>

struct file_parser_data
{
	uint16_t mode;
};

void init_file_parser(struct file_parser_data *fd)
{
	fd->mode = 0;
}

struct world
{
	struct file_parser_data fd;

};

void setup_world(struct world *w)
{
	init_file_parser(&w->fd);
}

void parse_file_byte(struct world *w, uint8_t b)
{
	printf("%c", b);
	switch (w->fd.mode)
	{
		case 0:
			if (isspace(b))
			{
				//do nothing, ignore the whitespace
			}
			else if (b == ';')
			{
				w->fd.mode = 1;
			}
			else if (isalpha(b))
			{
				w->fd.mode = 2;
				//todo: add b to array of word
			}
			break;
		case 1:	//comment mode, single line
			if ((b == '\n') || (b == '\r'))
			{
				w->fd.mode = 0;
			}
			break;
		case 2: //finding keyword mode
			if (isalnum(b) || isalpha(b))
			{
				//todo: add b to array of word
			}
			break;
		default:
			break;
	}
}

int main(int argc, char*argv[])
{
	int retval = 0;
	struct world theworld;
	setup_world(&theworld);
	if (argc != 3)
	{
		printf("Potato compiler stage0\nUsage: <stage0> <filename> <output>\n\t<filename> - The filename to compile.\n\t<output> - The filename to write output to.\n");
	}
	else
	{
		FILE *inp;
		inp = fopen(argv[1], "rb");
		if (inp)
		{
			while (!feof(inp))
			{
				uint8_t temp = fgetc(inp);
				parse_file_byte(&theworld, temp);
			}
			fclose(inp);
		}
		else
		{
			printf("Unable to open input file %s\n", argv[1]);
			retval = -1;
		}
	}
	return retval;
}
