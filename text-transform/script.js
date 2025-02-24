const inputText = document.getElementById('inputText');
const convertButton = document.getElementById('convertButton');
const outputText = document.getElementById('outputText');

// Function to transform the text and copy it to the clipboard
function transformAndCopyText() {
  const text = inputText.value.trim();
  const transformedText = text.toLowerCase().replace(/\s+/g, '-');
  outputText.textContent = transformedText;

  // Copy the transformed text to the clipboard
  navigator.clipboard
    .writeText(transformedText)
    .then(() => {
      // Change the button to indicate success
      convertButton.textContent = 'Text Copied!';
      convertButton.style.backgroundColor = 'green';
      convertButton.style.color = 'white';

      // Revert the button back to its original state after 2 seconds
      setTimeout(() => {
        convertButton.textContent = 'Convert';
        convertButton.style.backgroundColor = '#007bff';
        convertButton.style.color = 'white';
      }, 3000);
    })
    .catch((err) => {
      console.error('Failed to copy text: ', err);
    });
}

// Function to enable or disable the Convert button based on input
// Disable the button if the text area is empty
function toggleButtonState() {
  const text = inputText.value.trim();
  if (text === '') {
    convertButton.disabled = true;
    convertButton.style.backgroundColor = '#6c757d';
    convertButton.style.cursor = 'not-allowed';
    outputText.textContent = '';
  } else {
    convertButton.disabled = false;
    convertButton.style.backgroundColor = '#007bff';
    convertButton.style.cursor = 'pointer';
  }
}

// Add event listener to the Convert button
convertButton.addEventListener('click', transformAndCopyText);

// Add event listener to the text area to monitor input changes
inputText.addEventListener('input', toggleButtonState);

// Initialize the button state on page load
toggleButtonState();
