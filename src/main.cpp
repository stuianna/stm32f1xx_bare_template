#include <stm32f10x.h>

#define LED_PORT    GPIOC
#define LED_PIN     13  

void delayMs(uint16_t ms);

int main(void){


    // Set output mode, push-pull, 10MHz max.
    // Multiply pin by four as configuration field is 4 bits wide.
    // Need to subtract 8 from pin as the high control register is used.
    MODIFY_REG(LED_PORT->CRH,0x03<<((LED_PIN-8)*4),0x01<<((LED_PIN-8)*4));
    MODIFY_REG(LED_PORT->CRH,0x0C<<((LED_PIN-8)*4),0x00<<((LED_PIN-8)*4));

    while(1){

        // Set the LED pin and delay
        SET_BIT(LED_PORT->BSRR,0x1<<LED_PIN);
        delayMs(300);

        // Clear the LED pin and delay
        SET_BIT(LED_PORT->BRR,0x1<<LED_PIN);
        delayMs(300);
    }
}

void delayMs(uint16_t ms){

    for(uint16_t i = 0; i < ms; i++){
        for(uint16_t j = 0; j < 0xFFF; i++){
            __ASM("NOP");
        }
    }
}
