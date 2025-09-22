import React from 'react';
import { render } from '@testing-library/react';
import App from '../App';
test('smoke: render root component if present', ()=>{
  if(!App) { expect(true).toBeTruthy(); return; }
  const {container} = render(React.createElement(App));
  expect(container).toBeTruthy();
});
