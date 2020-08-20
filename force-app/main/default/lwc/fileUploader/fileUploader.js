import { LightningElement, wire } from "lwc";
import generateEncryptedToken from "@salesforce/apex/fileUploadController.generateEncryptedToken";
import associateFile from "@salesforce/apex/fileUploadController.associateFile";

export default class FileUploader extends LightningElement {
  recordId;
  encryptedToken;

  generateToken() {
    generateEncryptedToken({ recordId: this.recordId })
      .then((data) => {
        this.encryptedToken = data;
        console.log(this.encryptedToken);
      })
      .catch((error) => {
        console.log(error.message);
      });
  }

  handleValueChange(event) {
    this.recordId = event.target.value;
    console.log("recordId: " + this.recordId);
    this.generateToken();
  }

  get acceptedFormats() {
    return [".jpeg", ".png"];
  }

  handleUploadFinished(event) {
    associateFile({ token: this.encryptedToken })
      .then((data) => {})
      .catch((error) => {});
    const uploadedFiles = event.detail.files;
    console.log(JSON.stringify(event.detail.files));
  }
}
