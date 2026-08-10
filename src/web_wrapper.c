#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "sam.h"
#include "reciter.h"
#include "render.h"

int debug = 1;  /* enable rule/phoneme debug output for JS capture */

static int sam_result_samples = 0;
static char phonetic_output_buf[256];

int sam_web_synthesize(const char *text, int phonetic,
                       int pitch, int speed, int mouth, int throat,
                       int singmode)
{
    sam_result_samples = 0;
    phonetic_output_buf[0] = '\0';

    SetPitch((unsigned char)pitch);
    SetSpeed((unsigned char)speed);
    SetMouth((unsigned char)mouth);
    SetThroat((unsigned char)throat);
    if (singmode) EnableSingmode();

    char buf[256];
    int i;
    int l = (int)strlen(text);
    if (l > 254) l = 254;
    for (i = 0; i < l; i++)
        buf[i] = (char)toupper((unsigned char)text[i]);
    buf[l] = '\0';

    if (debug) printf("text input: %s\n", buf);

    if (!phonetic) {
        strncat(buf, " ", 255 - strlen(buf));
        strncat(buf, "[", 255 - strlen(buf));
        if (!TextToPhonemes((unsigned char *)buf)) return 0;
        /* store phonetic output, stripping the 0x9b sentinel */
        int pl = (int)strlen(buf);
        for (i = 0; i < pl && (unsigned char)buf[i] != 0x9b; i++)
            phonetic_output_buf[i] = buf[i];
        phonetic_output_buf[i] = '\0';
        if (debug) printf("phonetic input: %s\n", phonetic_output_buf);
    } else {
        strncat(buf, "\x9b", 255 - strlen(buf));
        strncpy(phonetic_output_buf, buf, 255);
    }

    SetInput(buf);
    if (!SAMMain()) return 0;

    sam_result_samples = GetBufferLength() / 50;
    return sam_result_samples;
}

char* sam_web_get_buffer(void) { return GetBuffer(); }
int sam_web_get_sample_count(void) { return sam_result_samples; }
int sam_web_get_sample_rate(void) { return 22050; }
int sam_web_get_error(void) { return GetSamError(); }
int sam_web_get_error_position(void) { return GetSamErrorPosition(); }

const char* sam_web_get_phonetic_output(void)
{
    return phonetic_output_buf;
}
