/* Nebulous */
#include <iostream>
#include <string.h>
#include <stdio.h>
int main(void) {
	int t0;
	int t1;
	int t2;
	bool t3;
	int t4;
	int t5;
	int t6;
	int t7;
	bool t8;
	int t9;

	t0 = 0;

	t1 = 8;
	t4 = t1;
BEGIN0:	t3 = t4 <= 0;
	t3 = !t3;
	if (t3) goto END0;

	t4 = t4 - 1;
	t1 = t1 * t4;

	goto BEGIN0;
	END0:
	t2 = t1;
	t0 = t2;

	t6 = 4;
BEGIN1:	t8 = t9 > t6;
	t8 = !t8;
	if (t8) goto END1;

	t5 = t5 * t5;
	t9 = t9 + 1;

	goto BEGIN1;
	END1:
	t7 = t5;
	t0 = t7;

	return 0;
}
