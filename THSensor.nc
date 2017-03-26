interface Temperature {

  /**
   * Resets the sensor.
   *
   * @return SUCCESS if the sensor will be reset
   */
  command error_t reset();

  /**
   * Signals that the sensor has been reset.
   *
   * @param result SUCCESS if the reset succeeded
   */
  event void resetDone( error_t result );

  /**
   * Starts a temperature measurement.
   *
   * @return SUCCESS if the measurement will be made
   */
  command error_t measureTemperature();

  /**
   * Presents the result of a temperature measurement.
   *
   * @param result SUCCESS if the measurement was successful
   * @param val the temperature reading
   */
  event void measureTemperatureDone( error_t result, uint16_t val );

  /**
   * Starts a humidity measurement.
   *
   * @return SUCCESS if the measurement will be made
   */  
  command error_t measureHumidity();

  /**
   * Presents the result of a humidity measurement.
   *
   * @param result SUCCESS if the measurement was successful
   * @param val the humidity reading
   */
  event void measureHumidityDone( error_t result, uint16_t val );

}
